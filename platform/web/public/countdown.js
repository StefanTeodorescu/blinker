ko.bindingHandlers.countdown = {
    init: function(element, valueAccessor, allBindings, viewModel, bindingContext) {
    },
    update: function(element, valueAccessor, allBindings, viewModel, bindingContext) {
        var current = $(element).data('countdown');

        if (current != null && current != undefined)
            current.stop();

        var deadline = ko.unwrap(valueAccessor());
        var countdown = $(element)
            .countdown(deadline,
                       { elapse: false,
                         precision: 300,
                         defer: false })
            .on('update.countdown', function(event) {
                $(this).text(
                    event.strftime('Time left: %H:%M:%S')
                );
            })
            .on('finish.countdown', function(event) {
                viewModel.timeUp(true);
                $(this).text('Time is up!');
            });
        $(element).data('countdown', countdown);
    }
};
